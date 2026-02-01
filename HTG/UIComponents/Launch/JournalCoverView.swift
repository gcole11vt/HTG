import SwiftUI

struct JournalCoverView: View {
    let ownerName: String

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Leather background
                RoundedRectangle(cornerRadius: 8)
                    .fill(JournalTheme.leatherBrown)
                    .shadow(color: .black.opacity(0.4), radius: 10, x: 5, y: 5)

                // Leather texture overlay (gradient simulation)
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                JournalTheme.leatherDark.opacity(0.3),
                                Color.clear,
                                JournalTheme.leatherDark.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Spine edge effect
                HStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    JournalTheme.leatherDark,
                                    JournalTheme.leatherBrown
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 20)
                    Spacer()
                }

                // Content
                VStack(spacing: 0) {
                    // Title at top center
                    titleSection
                        .padding(.top, geometry.size.height * 0.1)

                    Spacer()

                    // Owner name at bottom right
                    ownerSection
                        .padding(.bottom, geometry.size.height * 0.1)
                        .padding(.trailing, 30)
                }
                .padding(.leading, 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var titleSection: some View {
        VStack(spacing: 4) {
            Text("HIT THE")
                .font(JournalTheme.blockFont(size: 32))
                .foregroundStyle(JournalTheme.goldEmboss)

            Text("GREEN")
                .font(JournalTheme.blockFont(size: 40))
                .foregroundStyle(JournalTheme.goldEmboss)
        }
        .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
    }

    private var ownerSection: some View {
        VStack(alignment: .trailing, spacing: 2) {
            ForEach(nameComponents, id: \.self) { component in
                Text(component)
                    .font(JournalTheme.blockFont(size: 24))
                    .foregroundStyle(JournalTheme.goldEmboss)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .shadow(color: .black.opacity(0.3), radius: 1, x: 1, y: 1)
    }

    private var nameComponents: [String] {
        ownerName.uppercased().split(separator: " ").map(String.init)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.8)
            .ignoresSafeArea()

        JournalCoverView(ownerName: "Greg Cole")
            .frame(width: 300)
            .ignoresSafeArea()
    }
}
